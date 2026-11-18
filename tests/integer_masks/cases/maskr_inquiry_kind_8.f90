program p
implicit none
integer(8)::u
print *,maskr(2,kind=kind(u)),kind(maskr(u,kind=kind(u)))
end program
