program p
implicit none
integer(8)::a(0),u
print *,size(leadz(a)),kind(leadz(a))
print *,size(leadz([integer(8)::]+u))
end program
