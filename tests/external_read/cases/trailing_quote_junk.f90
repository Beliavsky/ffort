program p
implicit none
integer::stat,n
character(40)::text
character(8)::a,b
text="'a'b"
read(text,*,iostat=stat)a
if(stat<=0)stop 1
print '(a)', "OK"
end program
