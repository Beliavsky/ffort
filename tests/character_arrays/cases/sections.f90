implicit none
character(2)::a(-1:2)=["aa","bb","cc","dd"]
a(0:2:2)="x"
print *,a,a(2:-1:-1)//"!"
end
