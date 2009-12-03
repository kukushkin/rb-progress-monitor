# = ProgressMonitor
#
# This class allows to track an overall progress and estimated remaining time for
# a long task that consists of several stages.
#
# On task completion ProgressMonitor can report statistics on overall and per-stage performance.
#
# == Setting up
#
# Before we can measure the progress, the task should be split into stages, 
# and for each stage a plan and a metric (optionally) should be provided.
#
# For instance, let's imagine we are going to peel 10 oranges and crack 32 nuts. 
# The plan goes as:
#   plan = { :oranges => 10, :nuts => 32 }
#
# Next, we need to provide metrics. Metrics tell the ProgressMonitor how long is the single step 
# of particular stage relatively to the other stages. That's all the ProgressMonitor needs to know
# to measure the duration of the single stage and the whole process. 
#
# Back to our oranges. Let's say to peel an orange is 10 times longer than to crack a nut:
#   metrics = { :oranges => 10, :nuts => 1 }
# We could say as well that :oranges is 1 and :nuts is 0.1, only the proportions matter here. 
# The metrics could be omitted, then the ProgressMonitor assumes that all the stages are equal:
#   metrics = {} # means { :oranges => 1, :nuts => 1 }
#
# Next we create a ProgressMonitor instance with prepared plan and metrics:
#   p = ProgressMonitor.new :plan => plan, :metrics => metrics
#
#
# == Starting/monitoring task
#
# Once the ProgressMonitor is set, we can proceed to our task:
#
#   p.start :all # marks the beginning of the task
# 
#   p.start :oranges # let's begin with oranges
#   oranges.each do |orange|
#     orange.peel 
#     p.step # tells the ProgressMonitor that we've done another orange
#   end
#   p.finish :oranges # we've done with all the oranges
#
#   p.start :nuts # now let's crack some nuts
#   nuts.each do |nut|
#     nuts.crack
#     p.step
#   end
#   p.finish :nuts # done
#
#   p.finish :all # marks the end of the task
#
# == Getting progress
#
# Now what about progress? It's what the ProgressMonitor is really for. At any moment during
# the task, even after its completion, you can access a set of handy methods which tell you
# everything about the progress:
#
#   p.progress # the overall progress
#   p.time_started
#   p.time_elapsed
#   p.time_eta
#   p.time_finished
#
# == What else?
#
# After the task completion you can get the data on how well each stage performed:
#   pp p.stats 
#
# Remember, the more correct the metrics are, the more close are the estimated times 
# and the progress.
#
class ProgressMonitor
  VERSION = '1.0.2'

	attr_accessor :plan, :metrics
	attr_reader :time_started, :time_finished
	
	# Creates a new ProgressMonitor.
	#
	# Accepts a hash where metrics and plan for the task should be set.
	#
	# p = ProgressMonitor.new :plan => plan, :metrics => metrics
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