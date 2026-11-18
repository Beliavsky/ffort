program p
implicit none
integer::stat
character(40)::text
character(4)::a(4)
text=",'new',/"
a='old'
read(text,*,iostat=stat)a
if(stat/=0.or.a(1)/='old'.or.a(2)/='new'.or.any(a(3:)/='old'))stop 1
print '(a)', "OK"
end program
