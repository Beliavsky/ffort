program p
implicit none
integer(4)::a(0),u
print *,size(leadz(a)),kind(leadz(a))
print *,size(leadz([integer(4)::]+u))
end program
