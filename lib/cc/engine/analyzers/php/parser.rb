require 'cc/engine/analyzers/php/ast'
require 'cc/engine/analyzers/php/nodes'

module CC
  module Engine
    module Analyzers
      module Php
        class Parser
          attr_reader :code, :filename, :syntax_tree

          def initialize(code, filename)
            @code = code
            @filename = filename
          end

          def parse
            runner = CommandLineRunner.new("php #{parser_path}")
            runner.run(code) do |output|
              json = JSON.parse(output)

              @syntax_tree = CC::Engine::Analyzers::Php::Nodes::Node.new.tap do |node|
                node.stmts = CC::Engine::Analyzers::Php::AST.json_to_ast(json, filename)
                node.node_type = "AST"
              end
            end

            self
          end

        private

          def parser_path
            relative_path = "../../../../../vendor/php-parser/parser.php"
            File.expand_path(
              File.join(File.dirname(__FILE__), relative_path)
            )
          end
        end

        class CommandLineRunner
          attr_reader :command, :delegate

          DEFAULT_TIMEOUT = 20

          def initialize(command)
            @command = command
          end

          def run(input, timeout = DEFAULT_TIMEOUT)
            Timeout.timeout(timeout) do
              Open3.popen3 command, "r+" do |stdin, stdout, stderr, wait_thr|
                stdin.puts input
                stdin.close

                exit_code = wait_thr.value

                output = stdout.gets
                stdout.close

                err_output = stderr.gets
                stderr.close

                if 0 == exit_code
                  yield output
                else
                  raise ::CC::Engine::Analyzers::ParserError, "Python parser exited with code #{exit_code}:\n#{err_output}"
                end
              end
            end
          end
        end
      end
    end
  end
end

