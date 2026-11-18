program p
implicit none
integer(4)::u
print *,maskl(2,kind=kind(u)),kind(maskl(u,kind=kind(u)))
end program
