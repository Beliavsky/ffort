program p
implicit none
character(20)::lines(3)
integer::n,i,ios
lines(1)=""
read(lines(1),*,iostat=ios)n
if(ios>=0)stop 1
print '(a)', "OK"
end program
