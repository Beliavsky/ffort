program p
implicit none
integer::u,ios
character(2)::a(3)

u=27
a='--'

read(u,'(a)',iostat=ios)a(len([character(f())::"x"]))
if(ios/=0)stop 1
if(a(1)/='--'.or.a(2)/='xy'.or.a(3)/='--')stop 2
print '(a)',a(2)
contains
pure integer function f() result(n)
n=2
end function
end program
