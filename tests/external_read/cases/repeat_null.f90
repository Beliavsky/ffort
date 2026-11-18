program p
implicit none
integer::stat
character(30)::text
character(3)::a(3)
text='2*,new'
a='old'
read(text,*,iostat=stat)a
if(stat/=0.or.any(a(:2)/='old').or.a(3)/='new')stop 1
print '(a)', "OK"
end program
