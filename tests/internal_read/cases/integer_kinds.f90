program p
implicit none
character(80)::text
integer(8)::a(3),stat
integer::n
text='2147483647 9007199254740993 -9223372036854775808 9223372036854775807'
read(text,*,iostat=stat) n,a
if(stat/=0.or.n/=2147483647) stop 1
if(any(a/=[9007199254740993_8,-9223372036854775807_8-1_8,9223372036854775807_8])) stop 2
print *,1
end program
