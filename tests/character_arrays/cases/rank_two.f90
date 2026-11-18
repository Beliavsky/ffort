implicit none
character(2)::a(2,2)="x"
a(:,1)=["ab","cd"]
a(1,2)="yz"
print *,a,"!"//a,a=="x"
end
