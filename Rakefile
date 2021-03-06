#encoding: utf-8
namespace :links do
    require 'html-proofer'
    require 'optparse'

    files_ignore = []
    note = '(This can take a few mins to run) '

    desc 'Build site'
    task :build do
        if ARGV.length > 0
          if ARGV.include? "quiet"
            quiet = '-q'

            # BLACK MAGIC TO HIJACK ARG AS A TASK
            task ARGV.last.to_sym do ; end
          else
            quiet = ''

            # BLACK MAGIC TO HIJACK ARG AS A TASK
            task ARGV.last.to_sym do ; end
          end
        end

        puts
        puts "Building site..."
        sh 'mkdocs build -f mkdocs.yml -d site' + ' ' + String(quiet)
    end

    desc 'Checks html files for broken external links'
    task :test_external, [:ARGV] do
        # Verify regex at https://regex101.com
        options = {
            :assume_extension   => true,
            :log_level          => :info,
            :external_only      => true,
            :internal_domains   => ["https://instructor.labs.sysdeseng.com", "https://www.youtube.com"],
            :url_ignore         => [ /http(s)?:\/\/(www.)?katacoda.com.*/ ],
            :url_swap           => {'https://kubevirt.io/' => '',},
            :http_status_ignore => [0, 400, 429, 999]
        }

        parser = OptionParser.new
        parser.banner = "Usage: rake -- [arguments]"
        # Added option -u which will remove the url_swap option to from the map
        parser.on("-u", "--us", "Remove url_swap from htmlProofer") do |url_swap|
            options.delete(:url_swap)
        end

        args = parser.order!(ARGV) {}
        parser.parse!(args)

        puts
        puts "Checks html files for broken external links " + note + "..."
        HTMLProofer.check_directory("./site", options).run
    end

    desc 'Checks html files for broken internal links'
    task :test_internal do
        options = {
            :assume_extension   => true,
            :allow_hash_href    => true,
            :log_level          => :info,
            :disable_external   => true,
            :url_swap           => {'/user-guide' => '',},
            :http_status_ignore => [0, 200, 400, 429, 999]
        }

        puts
        puts "Checks html files for broken internal links " + note + "..."
        HTMLProofer.check_directory("./site", options).run
    end
end

desc 'The default task will execute all tests in a row'
task :default => ['links:build', 'links:test_external', 'links:test_internal']
