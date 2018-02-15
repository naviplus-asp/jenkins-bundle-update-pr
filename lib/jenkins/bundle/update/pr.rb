# frozen_string_literal: true

require 'jenkins/bundle/update/pr/version'

require 'compare_linker'
require 'octokit'

class CompareLinker
  def make_compare_links
    if octokit.pull_request_files(repo_full_name, pr_number).find do |resource|
      resource.filename == 'Gemfile.lock' || resource.filename == 'config/Gemfile.lock'
    end
      pull_request = octokit.pull_request(repo_full_name, pr_number)

      fetcher = LockfileFetcher.new(octokit)
      old_lockfile = fetcher.fetch(repo_full_name, pull_request.base.sha)
      new_lockfile = fetcher.fetch(repo_full_name, pull_request.head.sha)

      comparator = LockfileComparator.new
      comparator.compare(old_lockfile, new_lockfile)
      @compare_links = comparator.updated_gems.map do |gem_name, gem_info|
        if gem_info[:owner].nil?
          finder = GithubLinkFinder.new(octokit)
          finder.find(gem_name)
          if finder.repo_owner.nil?
            gem_info[:homepage_uri] = finder.homepage_uri
            formatter.format(gem_info)
          else
            gem_info[:repo_owner] = finder.repo_owner
            gem_info[:repo_name] = finder.repo_name

            tag_finder = GithubTagFinder.new(octokit)
            old_tag = tag_finder.find(finder.repo_full_name, gem_info[:old_ver])
            new_tag = tag_finder.find(finder.repo_full_name, gem_info[:new_ver])

            if old_tag && new_tag
              gem_info[:old_tag] = old_tag.name
              gem_info[:new_tag] = new_tag.name
              formatter.format(gem_info)
            else
              formatter.format(gem_info)
            end
          end
        else
          formatter.format(gem_info)
        end
      end
      @compare_links
    end
  end

  class LockfileFetcher
    def fetch(repo_full_name, ref)
      lockfile_content = octokit.contents(
        repo_full_name, ref: ref
      ).find do |content|
        content.name == 'Gemfile.lock' || content.name == 'config/Gemfile.lock'
      end
      Bundler::LockfileParser.new(
        Base64.decode64(
          octokit.blob(repo_full_name, lockfile_content.sha).content
        )
      )
    end
  end
end

module Jenkins
  module Bundle
    module Update
      module Pr
        def self.create_if_needed(git_username: nil, git_email: nil)
          raise "$GITHUB_PROJECT_USERNAME isn't set" unless ENV['GITHUB_PROJECT_USERNAME']
          raise "$GITHUB_PROJECT_REPONAME isn't set" unless ENV['GITHUB_PROJECT_REPONAME']
          raise "$GITHUB_ACCESS_TOKEN isn't set" unless ENV['GITHUB_ACCESS_TOKEN']

          return unless need?

          now = Time.now

          git_username ||= client.user.login
          git_email    ||= "#{git_username}@users.noreply.github.com"

          repo_full_name = "#{ENV['GITHUB_PROJECT_USERNAME']}/#{ENV['GITHUB_PROJECT_REPONAME']}"
          branch         = "bundle-update-#{now.strftime('%Y%m%d%H%M%S')}"

          create_branch(git_username, git_email, branch)
          pull_request = create_pull_request(repo_full_name, branch, now)
          add_comment_of_compare_linker(repo_full_name, pull_request[:number])
        end

        def self.need?
          system('bundle update') || raise
          `git status -s 2> /dev/null`.include?('Gemfile.lock')
        end
        private_class_method :need?

        def self.create_branch(git_username, git_email, branch)
          system("git config user.name #{git_username}")
          system("git config user.email #{git_email}")
          system("git checkout -b #{branch}")
          system('git add Gemfile.lock config/Gemfile.lock')
          system("git commit -m 'bundle update'")
          system("git push origin #{branch}")
        end
        private_class_method :create_branch

        def self.create_pull_request(repo_full_name, branch, now)
          title = "bundle update at #{now.strftime('%Y-%m-%d %H:%M:%S %Z')}"
          body  = "auto generated by [Jenkins of #{ENV['JOB_NAME']}](#{ENV['BUILD_URL']})"
          client.create_pull_request(repo_full_name, 'master', branch, title, body)
        end
        private_class_method :create_pull_request

        def self.add_comment_of_compare_linker(repo_full_name, pr_number)
          ENV['OCTOKIT_ACCESS_TOKEN'] = ENV['GITHUB_ACCESS_TOKEN']
          compare_linker = CompareLinker.new(repo_full_name, pr_number)
          compare_linker.formatter = CompareLinker::Formatter::Markdown.new

          comment = <<~COMMENT
            #{compare_linker.make_compare_links.to_a.join("\n")}

            Powered by [compare_linker](https://rubygems.org/gems/compare_linker)
          COMMENT

          compare_linker.add_comment(repo_full_name, pr_number, comment)
        end
        private_class_method :add_comment_of_compare_linker

        def self.client
          Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
        end
        private_class_method :client
      end
    end
  end
end
