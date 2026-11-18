implicit none
character(*),parameter::a(0)=[character(7)::],b(0,2)=reshape([character(4)::],[0,2])
print *,size(a),size(b)
end
