program p
implicit none
integer::stat
character(30)::text
character(3)::a(3)
text="2*'',xx"
a='old'
read(text,*,iostat=stat)a
if(stat/=0.or.any(a(:2)/=' ').or.a(3)/='xx')stop 1
print '(a)', "OK"
end program
