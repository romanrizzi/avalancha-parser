# frozen_string_literal: true

module Compilation
  class Program
    def initialize(tags)
      @checks = ''
      @tags = tags
      @prototypes = []
      @functions = []
    end

    def add_prototype(prototype)
      @prototypes << prototype
    end

    def add_function(function)
      @functions << function
    end

    def add_check(code)
      @checks += code
    end

    def to_s
      @code = ''

      apply_headers
      add_base_defs
      define_utility_functions

      @prototypes.each { |p| @code += [p, "\n"].join }
      @functions.each { |p| @code += [p, "\n"].join }

      @code += <<~HEREDOC

        int main() {
            #{add_tags}
            #{@checks}
            return 0;
        }
      HEREDOC
    end

    private

    def spaces
      "\x20\x20\x20"
    end

    def apply_headers
      @code += <<~HEREDOC
        #include <vector>
        #include <string>
        #include <iostream>
        #include <map>
        using namespace std;\n
      HEREDOC
    end

    def add_base_defs
      @code += <<~HEREDOC
        typedef int Tag;
        struct Term {
          Tag tag;
          vector<Term*> children;
          int refcnt;
        };\n
      HEREDOC
    end

    def define_utility_functions
      @code += <<~HEREDOC
        void incref(Term* t) {
            t->refcnt = t->refcnt++;
        }

        void decref(Term* t) {
            
        }

        void printTerm(Term* t, std::map<int, std::string> tags) {
          cout << tags[t->tag];
          
          if (t->children.size() > 0) {
            cout << "(";

            for(int i = 0; i < t->children.size(); i++) {
              if (i > 0) {
                cout << ", ";
              }
              printTerm(t->children[i], tags);
            }

            cout << ")";
          }
        }

        bool eqTerms(Term* t1, Term* t2) {
          return 1;
        }\n
      HEREDOC
    end

    def add_tags
      tag_allocations = @tags.reduce('') do |memo, (k, v)|
        memo + "#{spaces} tags[#{v}] = \"#{k}\";\n"
      end

      <<~HEREDOC
        std::map<int, std::string> tags;
        #{tag_allocations}
      HEREDOC
    end
  end
end
