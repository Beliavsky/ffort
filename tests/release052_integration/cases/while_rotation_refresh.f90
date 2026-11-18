program main
implicit none
character(2)::x(3)
integer::i
x=['A ','B ','C ']
i=0
do while(i<3)
  print '(3a2)',x([3,1,2])
  x=x([2,3,1])
  i=i+1
end do
end program
