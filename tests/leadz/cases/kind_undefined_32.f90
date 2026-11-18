program p
implicit none
integer(4)::u
integer(4),allocatable::a(:,:)
print *,kind(leadz(u)),kind(leadz(a)),kind(leadz(a(999,999)))
end program
