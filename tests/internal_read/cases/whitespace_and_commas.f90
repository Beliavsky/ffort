program p
implicit none
character(40)::text
integer::a(3),stat
text=' 1 , 2'//achar(9)//' 3   '
read(text,*,iostat=stat) a
if(stat/=0.or.any(a/=[1,2,3])) stop 1
print *,1
end program
