program p
implicit none
character(len=*),parameter::fmt='(2(i0,1x),l1)'
real,allocatable::a(:,:)
a=reshape([1.0,2.0,10.0,20.0],[2,2])
a=a([integer::],:)
write(*,fmt) shape(a),allocated(a)
end program
