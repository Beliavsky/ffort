program p
implicit none
character(65536)::text
integer::n,stat
text="12"
read(text,*,iostat=stat) n
if(stat/=0.or.n/=12) stop 1
print *,1
end
