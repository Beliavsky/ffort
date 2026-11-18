implicit none
character(3)::a(0)=[character(3)::]
print *,size(a),kind(a),size(a//"x")
end
