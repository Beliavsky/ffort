program main
implicit none
character(20)::s
integer::a(3),n
a=[1,2,3]
n=3
write(s,'(2(i2))') a(:n)
end program
