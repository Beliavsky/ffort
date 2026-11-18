program p
implicit none
character(60)::text
integer::a(7),stat
a=[1,2,3,4,5,6,7]
text=',2*,8,,/ invalid remainder'
read(text,*,iostat=stat) a
if(stat/=0.or.any(a/=[1,2,3,8,5,6,7])) stop 1
print *,1
end program
