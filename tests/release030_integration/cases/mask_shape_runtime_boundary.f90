! Synthetic release 0.30 composition fixture; not an extracted utility body.
program composition
implicit none
integer a(3)
logical,allocatable :: selected(:)
a=[4,4,4]
allocate(selected(2))
selected=.true.
print *,findloc(a,4,mask=selected)
end program
