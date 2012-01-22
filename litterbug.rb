require 'date'

module LitterBug
  class LitterBox
    attr_reader :last_action, :action_count

    def initialize(logger = Logger.new($stdout))
      @last_action = Time.at(0)
      @action_count = 0
    end

    def action_performed
      @last_action = Time.now
      @action_count += 1
      @logger.info "Action performed on litterbox, state: " + self.to_s
    end

    def to_s
      "action count: #{@action_count}, last action #{@last_action}"
    end
  end


  class Timer
    def every_day_at(hh, mm, &block)
      @work = block
      @hh, @mm = hh, mm
    end

    def start
      t = Thread.new do
        while true
          seconds_to_wait = next_run_time - Time.now
          sleep seconds_to_wait
          perform_work
        end
      end
      t.start
    end

    private
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
    def self.run
      self.new.run
    end

    def initialize(litterbox)
      @litterbox = litterbox
      @timer = Timer.new
      @timer.every_day_at(10, 00) do
        check
      end
    end

    def run
      @timer.start
    end

    def check
      six_hours_ago = Time.now - (6 * 60 * 60)
      while @litterbox.last_action < six_hours_ago
        alert
      end
    end
  end

  class Human
    def initialize(litterbox)
      @litterbox = litterbox
    end

    def run
      t = Thread.new do
        while true
          gets 
          @litterbox.action_performed
        end
      end
      t.start
    end
  end
end

LitterBug::Watcher.run
