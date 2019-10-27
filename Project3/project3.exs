defmodule Caller do
	def exec do
		Project.start([String.to_integer(Enum.at(System.argv(), 0)), String.to_integer(Enum.at(System.argv(), 1))])
	end
end
Caller.exec
