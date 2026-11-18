! Synthetic release 0.30 composition fixture; not an extracted utility body.
program composition
implicit none
logical,allocatable selected(:,:)
allocate(selected(1,1))
selected=.true.
print *,shape(selected)
end program
