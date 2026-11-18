program p
implicit none
character(2)::a="a ",b="bb"
print *,merge(trim(a),trim(b),.true.)
end program
