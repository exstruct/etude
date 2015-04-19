defmodule ExprTest.Comprehension do
  use ExUnit.Case
  use ExprTestHelper

  exprtest "should render a static comprehension", [
    render: [
      %Comprehension{
        collection: [1,2,3,4,5],
        expression: :ITEM
      }
    ]
  ], [:ITEM, :ITEM, :ITEM, :ITEM, :ITEM]

  exprtest "should render a value comprehension", [
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

  exprtest "should render a key/value comprehension", [
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
end