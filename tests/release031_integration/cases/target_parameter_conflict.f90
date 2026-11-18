! Synthetic release 0.31 composition fixture; not an extracted utility body.
program composition
implicit none
integer,target,parameter :: size_hint=2
logical,allocatable :: flags(:)
allocate(flags(size_hint));flags=.true.
print *,shape(flags)
end program
