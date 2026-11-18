implicit none
character(2)::a(2,2)="q"
a(:,1)=["ab","cd"]
a(:,2)=a(2:1:-1,1)
print *,a(1,:),a(:,2)//"!"
end
