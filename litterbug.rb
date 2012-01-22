require 'logger'

module LitterBug

  class LitterBox
    attr_reader :last_action, :action_count

    def initialize(logger)
      @last_action = Time.at(0)
      @action_count = 0
      @logger = logger
    end

    def action_performed
      @last_action = Time.now
      @action_count += 1
      @logger.info "Action performed on litterbox, state: " + self.to_s
    end

    def needs_cleaning?
      @action_count % 10 == 0
    end

    def to_s
      "action count: #{@action_count}, last action #{@last_action}, needs cleaning: #{needs_cleaning?}"
    end
  end


  class Timer
    def initialize(logger)
      @logger = logger
    end

    def every_day_at(hh, mm, &block)
      @work = block
      @hh, @mm = hh, mm
    end

    def start
      Thread.new do
        while true
          seconds_to_wait = next_run_time - Time.now
          @logger.info("Timer sleeping #{seconds_to_wait} seconds")
          sleep seconds_to_wait
          @logger.debug("Timer performing work")
          perform_work
        end
      end
    end

    def next_run_time
      now = Time.now
      run_time = Time.local(now.year, now.month, now.day, @hh, @mm)
      if run_time < now
        run_time += (24 * 60 * 60)
      end
      run_time
    end

    def perform_work
      @work.call
    end
  end


  class Watcher
    def initialize(litterbox, logger)
      @logger = logger
      @litterbox = litterbox
      @alerter = Alerter.new(logger)
      @timer = Timer.new(logger)
    end

    def start
      @logger.info "Watcher: Starting watching litterbox every day at 10:00"
      @timer.every_day_at(10, 00) do
        check
      end
      @timer.start
    end

    def check
      six_hours_ago = Time.now - (6 * 60 * 60)
      while @litterbox.last_action < six_hours_ago
        alert
        sleep 1
      end
    end

    def alert
      if @litterbox.needs_cleaning?
        @alerter.cleaning_needed
      else
        @alerter.emptying_needeed
      end
    end
  end


  class Alerter
    def initialize(logger)
      @logger = logger
    end

    def cleaning_needed
      puts "CLEANING needed"
    end

    def emptying_needeed
      puts "EMPTYING needed"
    end
  end


  class Human
    def initialize(litterbox, logger = Logger.new($stdout))
      @litterbox = litterbox
      @logger = logger
      @logger.info("Starting human loop")
      run
    end

    def run
      while true
        gets 
        @litterbox.action_performed
      end
    end
  end

  class Runner
    def self.run
      logger = Logger.new($stdout)
      
      litterbox = LitterBox.new(logger)
      Watcher.new(litterbox, logger).start
      Human.new(litterbox, logger).run
    end
  end
end

if $0 == __FILE__
  LitterBug::Runner.run
end
