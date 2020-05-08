namespace :puma do
  desc 'Start puma as daemon'
  task :start do
    on roles(:web), in: :groups, limit: 3 do
      within current_path do
        with rails_env: fetch(:rails_env) do
          execute :bundle, 'exec puma -C config/puma.rb --daemon'
        end
      end
    end
  end

  %w{stop restart phased-restart status stats}.map do |command|
    desc "Run pumactl #{command}"
    task command do
      on roles(:web), in: :groups, limit: 3 do
        within current_path do
          with rails_env: fetch(:rails_env) do
            execute :bundle, 'exec pumactl',
              "-S #{shared_path}/tmp/pids/puma.state",
              command
          end
        end
      end
    end
  end
end

