program p
implicit none
character(80)::text
real(8)::x
integer::stat
text='2.2250738585072014D-308'
read(text,*,iostat=stat) x
if(stat/=0.or.x/=tiny(x)) stop 1
print *,1
end program
