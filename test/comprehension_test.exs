defmodule EtudeTest.Comprehension do
  use EtudeTestHelper

  etudetest "should render a static comprehension", [
    render: [
      %Comprehension{
        collection: [1,2,3,4,5],
        expression: :ITEM
      }
    ]
  ], [:ITEM, :ITEM, :ITEM, :ITEM, :ITEM]

  etudetest "should render a value comprehension", [
    render: [
      %Comprehension{
        collection: [1,2,3,4,5],
        expression: %Var{
          name: :value
        },
        value: %Assign{
          name: :value
        }
      }
    ]
  ], [1,2,3,4,5]

  etudetest "should render a key-value comprehension", [
    render: [
      %Comprehension{
        collection: [1,2,3,4,5],
        expression: {
          %Var{name: :key},
          %Var{name: :value},
        },
        key: %Assign{name: :key},
        value: %Assign{name: :value}
      }
    ]
  ], [{0,1},{1,2},{2,3},{3,4},{4,5}]

  etudetest "should render a key-value map comprehension", [
    render: [
      %Comprehension{
        collection: %{"foo" => "bar", "baz" => "bang"},
        expression: {
          %Var{name: :value},
          %Var{name: :key}
        },
        key: %Assign{name: :key},
        value: %Assign{name: :value},
        type: :map
      }
    ]
  ], %{"bar" => "foo", "bang" => "baz"}

  etudetest "should support a nested comprehension", [
    render: [
      %Comprehension{
        collection: [1,2,3],
        expression: %Comprehension{
          collection: [1,2,3],
          expression: [%Var{name: :value1}, %Var{name: :value2}],
          value: %Assign{
            name: :value2
          }
        },
        value: %Assign{
          name: :value1
        }
      }
    ]
  ], [[[1, 1], [1, 2], [1, 3]],
      [[2, 1], [2, 2], [2, 3]],
      [[3, 1], [3, 2], [3, 3]]]

  etudetest "should pull in variables from outside of the scope", [
    render: [
      %Assign{
        expression: %Var{name: :rzc},
        name: false
      },
      %Assign{
        expression: %Cond{
          arms: [
            %Comprehension{}
          ]
        },
        name: :rzc
      },
      nil
    ]
  ], nil
end