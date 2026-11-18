program main
implicit none
integer::a(2)=[1,2]
real::b(2)=[1.25,3.5]
logical::c(2)=[.true.,.false.]
print '(a,2i3,2f7.2,2l2,a)',"left",a,b,c,"right"

end program
