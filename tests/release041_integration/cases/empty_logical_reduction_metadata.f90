program p
implicit none
character(len=*),parameter::fmt='(3(l1,1x),i0)'
logical,allocatable::mask(:)
mask=[logical::]
print fmt,all(mask),any(mask),allocated(mask),kind([logical::])
end program
