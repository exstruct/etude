defmodule EtudeTest.Cons do
  use EtudeTestHelper

  etudetest "should construct a cons", [
    render: [
      %Cons{
        expression: [4,5],
        children: [1,2,3]
      }
    ]
  ], [1,2,3,4,5]
end
