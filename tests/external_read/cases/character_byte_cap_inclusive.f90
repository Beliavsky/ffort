program p
implicit none
integer::stat
character(20)::text
character(65536)::a(256)
text='256*x'
read(text,*,iostat=stat)a
if(stat/=0.or.a(1)/='x'.or.a(256)/='x')stop 1
print '(a)','OK'
end program
