program p
implicit none
integer(8)::u
integer(8),allocatable::a(:,:)
print *,kind(leadz(u)),kind(leadz(a)),kind(leadz(a(999,999)))
end program
