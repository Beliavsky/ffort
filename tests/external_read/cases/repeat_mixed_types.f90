program p
implicit none
integer::n,stat
character(30)::text
character(4)::a(2)
text='3*12'
read(text,*,iostat=stat)n,a
if(stat<=0)stop 1
print '(a)', "OK"
end program
