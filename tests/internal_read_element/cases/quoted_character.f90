program p
implicit none
character(64)::a(1)
character(12)::x,y
a(1)='"hello world", "a,b"'
read(a(1),*)x,y
if(x/="hello world".or.y/="a,b")stop 1
print '(a)', "OK"
end program
