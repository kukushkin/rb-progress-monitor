# = ProgressMonitor
#
# This class allows to track an overall progress and estimated remaining time for
# a long task that consists of several stages.
#
# On task completion ProgressMonitor can report statistics on overall and per-stage performance.
#
class ProgressMonitor
  VERSION = '1.0.1'

	attr_accessor :plan, :metrics
	attr_reader :time_started, :time_finished
	
	# Creates a new ProgressMonitor.
	#
	def initialize( opts = nil )
		unless opts.nil?
			@metrics = opts[:metrics] || {}
			@plan = opts[:plan] || {}
		else
			@metrics = {}
			@plan = {}
		end
				
		@state = :idle
		@current_stage = nil
		@stages = {}
		@progress = 0
		@steps_done = {}
		@time_started = nil
		@time_finished = nil
		@time_elapsed = nil
	end
	
	# Starts a task or a specific stage of it.
	#
	# To start a task use <tt>start :all</tt>.
	#
	def start( stage  )
		if stage == :all 
			@state = :working
			@time_started = Time.now
			@time_finished = nil
			@time_elapsed = nil
			@current_stage = nil
			@stages = {}
			@progress = 0
			@plan.keys.each do |s|
				register_stage s
			end
		else
			unless @current_stage.nil?
				raise "Failed to start new stage '#{stage}' while current stage '#{@current_stage}' is not finished."
			end
			
			@current_stage = stage
			unless @stages.include? stage
				register_stage stage
			end
			@stages[stage][:time_started] = Time.now
			@stages[stage][:time_finished] = nil
		end
		recalc_progress
	end
	
	# Returns current stage.
	#
	def current_stage
		@current_stage
	end
	
	# Increments number of steps done in the current stage.
	#
	def step( n = 1 )
		if @current_stage
			@stages[@current_stage][:steps_done] += n
		end
		recalc_progress
	end
	
	# Returns number of steps done in the current stage.
	#
	def done
	  if @current_stage
			@stages[@current_stage][:steps_done]
		else
		  nil
		end
	end
	
	# Sets the number of steps done in the current stage.
	#
	def done=( n )
		if @current_stage
			@stages[@current_stage][:steps_done] = n
		end
		recalc_progress
	end
	
	# Finishes a task or a specific stage of it.
	#
	# To finish a task use <tt>finish :all</tt>.
	#
	def finish( stage )
		if stage == :all
		  @state = :finished
		  @time_finished = Time.now
		  @time_elapsed = @time_finished - @time_started
		  @current_stage = nil
		else
			if @current_stage != stage
				raise "Failed to finish stage '#{stage}' because it's not started."
			end
			@stages[@current_stage][:time_finished] = Time.now
			@stages[@current_stage][:time_elapsed] += @stages[@current_stage][:time_finished] -
				@stages[@current_stage][:time_started]
			@current_stage = nil
		end
		recalc_progress
	end
	
  # Reports overall progress in percents.
  #
	def progress
		@progress
	end
	
	# Reports amount of time elapsed since task start.
	#
	def time_elapsed
		if @time_started.nil?
			nil
		elsif @time_finished.nil?
			Time.now - @time_started
		else
			@time_elapsed
		end
	end
	
	# Reports an estimated amount of time remaining to complete the task.
	#
	def time_remaining
		t = 0
		if @time_finished.nil?
			if @progress > 0
				remaining_progress = 100 - @progress
				if remaining_progress > 0
					t = remaining_progress * time_elapsed / @progress
				end
			else
				# progress is 0
				t = nil
			end
		end
		t
	end
	
	# Reports an estimated time at which the task will be finished.
	#
	def time_eta
		if time_remaining.nil?
			nil
		elsif @time_finished.nil?
			Time.now + time_remaining
		else
			@time_finished
		end
	end
	
	# Reports statistics by each stage.
	#
	def stats
		s = {}
		@stages.each do |stage, attrs|
			s[stage] = {
				:steps_planned => plan_for(stage),
				:steps_done => attrs[:steps_done],
				:time_started => attrs[:time_started],
				:time_finished => attrs[:time_finished],
				:time_elapsed => attrs[:time_elapsed]
			}	
			if ( attrs[:steps_done] > 0 ) && ( attrs[:time_elapsed] > 0 )
				s[stage][:effective_metric] = attrs[:time_elapsed]/attrs[:steps_done]
			else
				s[stage][:effective_metric] = 0
			end
		end
		
		s
	end
	
private

  # Registers a new stage with blank parameters.
  #
	def register_stage( stage )
		unless @stages.include? stage
			@stages[stage] = { 
				:steps_done => 0,
				:time_elapsed => 0
			}
		end
	end
	
	# Returns amount of steps planned for the stage or 0 if stage plan is unknown.
	#
	def plan_for( stage )
		@plan[stage] || 0
	end
	
	# Returns amount of steps planned for the stage or 1 if stage metric is unknown.
	#
	def metric_for( stage )
		@metrics[stage] || 1
	end

  # Recalculates overall progress.
  #
	def recalc_progress
		total_plan = 0
		total_done = 0
		@stages.each do |stage, attrs|
			p = plan_for stage
			total_plan += p * metric_for( stage )
			if attrs[:steps_done] < p
				total_done += attrs[:steps_done] * metric_for( stage )
			else
				total_done += p * metric_for( stage )
			end
		end
		
		if total_plan > 0
			@progress = total_done * 100.0 / total_plan
		else
			@progress = 0
		end
	end
	
	
end