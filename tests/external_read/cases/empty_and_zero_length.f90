program p
implicit none
integer::stat
character(2)::text
character(0)::z
character(3)::a(0)
text='xy'
read(text,*,iostat=stat)a
if(stat/=0)stop 1
read(text,*,iostat=stat)z
if(stat/=0.or.len(z)/=0)stop 2
print '(a)', "OK"
end program
