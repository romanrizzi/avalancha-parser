# frozen_string_literal: true

module Compilation
  class Program
    def initialize(tags)
      @code = ''
      @checks = ''
      @tags = tags
      @main_vars = 0

      apply_headers
      add_base_defs
      define_utility_functions
    end

    def to_s
      @code
    end

    def add_expression(tag:, var:, children:)
      children_refs = children.reduce('') do |memo, r|
        memo + "#{spaces} e_#{var}->children.push_back(e_#{r});\n"
      end

      @checks += <<~HEREDOC
        Term* e_#{var} = new Term();
        #{spaces} e_#{var}->tag = #{@tags[tag]};
        #{spaces} e_#{var}->refcnt = 0;
        #{children_refs}
      HEREDOC
    end

    def add_print(var_number)
      @checks += <<~HEREDOC
        #{spaces} incref(e_#{var_number});
        #{spaces} printTerm(e_#{var_number}, tags);
        cout << "\\n";
        #{spaces} decref(e_#{var_number});
      HEREDOC
    end

    def build_main_method
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
