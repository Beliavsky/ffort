program p
implicit none
character(0)::a(1)
integer::n,ios
a(1)=""
read(a(1),*,iostat=ios)n
if(ios>=0)stop 1
print '(a)', "OK"
end program
