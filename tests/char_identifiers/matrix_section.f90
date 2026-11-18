program p
implicit none
integer::char(2,2)
char=reshape([1,2,3,4],[2,2])
char(:,2)=char(:,1)+8
if(any(char(:,2)/=[9,10])) error stop 1
print *,char(:,2)
end program
