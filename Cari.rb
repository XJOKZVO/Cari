require 'net/http'
require 'json'
require 'io/console'

def display_logo
  puts "\e[32m" # Set color to green
  puts "   ____                  _ "
  puts "  / ___|   __ _   _ __  (_)"
  puts " | |      / _` | | '__| | |"
  puts " | |___  | (_| | | |    | |"
  puts "  \\____|  \\__,_| |_|    |_|"
  puts "                           \e[0m" # Reset color
end

def fetch_github_repositories(keyword, page = 1)
  url = URI("https://api.github.com/search/repositories?q=#{keyword}&page=#{page}")
  begin
    response = Net::HTTP.get(url)
    data = JSON.parse(response)
    items = data['items'].map do |item|
      {
        name: item['name'],
        url: item['html_url'],
        stars: item['stargazers_count'],
        forks: item['forks_count'],
        description: item['description']
      }
    end
    return items, data['total_count']
  rescue JSON::ParserError
    puts "\e[31mFailed to parse response from GitHub API.\e[0m"
    return [], 0
  rescue StandardError => e
    puts "\e[31mAn error occurred: #{e.message}\e[0m"
    return [], 0
  end
end

def display_animation
  3.times do
    1.upto(3) do |dots|
      print "\e[33mSearching#{'.' * dots}#{' ' * (3 - dots)}\r"
      sleep 0.5
    end
  end
  print "\e[0m\r"
end

def prompt_for_keyword
  print "\e[32mSearch for GitHub repositories. Enter a keyword: \e[0m"
  keyword = gets.chomp
  if keyword.empty?
    puts "\e[31mInvalid input. Please enter a non-empty keyword.\e[0m"
    return nil
  end
  keyword
end

def display_results(repositories)
  if repositories.empty?
    puts "\e[31m\nNo matching repositories found.\e[0m"
  else
    puts "\e[32m\nMatching GitHub Repositories:\e[0m"
    repositories.each_with_index do |repo, index|
      puts "\e[34m#{index + 1}. #{repo[:name]}\e[0m"
      puts "   URL: #{repo[:url]}"
      puts "   Stars: #{repo[:stars]}, Forks: #{repo[:forks]}"
      puts "   Description: #{repo[:description]}\n\n"
    end
  end
end

def prompt_for_page
  print "\e[32mEnter page number (or press Enter to exit): \e[0m"
  page = gets.chomp
  return nil if page.empty?
  page.to_i
end

def main
  Signal.trap("INT") do
    puts "\n\e[33mExiting the tool. Goodbye!\e[0m"
    exit
  end

  display_logo

  loop do
    keyword = prompt_for_keyword
    next unless keyword

    page = 1
    loop do
      display_animation
      repositories, total_count = fetch_github_repositories(keyword, page)
      display_results(repositories)
      
      if total_count > page * 30
        puts "\e[32m\nTotal repositories found: #{total_count}. Currently displaying page #{page}.\e[0m"
        next_page = prompt_for_page
        break unless next_page
        page = next_page
      else
        break
      end
    end
  end
end

if __FILE__ == $0
  main
end
