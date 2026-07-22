function [force_N,torque_Nm,diagnostics] = evaluate_maxwell_force_probe(model,fieldPrefix,center_m,halfSize_m,quadratureOrder)
%EVALUATE_MAXWELL_FORCE_PROBE Integrate air Maxwell stress on a closed cuboid.
% The probe must lie wholly in a mu_r=1 air region and enclose the target body.
validateattributes(center_m,{'numeric'},{'real','finite','vector','numel',3});
validateattributes(halfSize_m,{'numeric'},{'real','finite','scalar','positive'});
validateattributes(quadratureOrder,{'numeric'},{'real','finite','scalar','integer','>=',2});
center_m=double(center_m(:)).';prefix=char(fieldPrefix);mu0=4*pi*1e-7;
[g,w]=gauss_legendre_force_probe(quadratureOrder);[U,V]=meshgrid(g,g);[WU,WV]=meshgrid(w,w);weights=(halfSize_m^2)*(WU.*WV);weights=weights(:);
force_N=zeros(1,3);torque_Nm=zeros(1,3);maxB_T=0;pointCount=0;
for dim=1:3
    for side=[-1 1]
        points=zeros(numel(U),3);other=setdiff(1:3,dim);
        points(:,dim)=center_m(dim)+side*halfSize_m;
        points(:,other(1))=center_m(other(1))+halfSize_m*U(:);
        points(:,other(2))=center_m(other(2))+halfSize_m*V(:);
        coords=points.';
        B=[mphinterp(model,[prefix '.Bx'],'coord',coords,'unit','T').', ...
           mphinterp(model,[prefix '.By'],'coord',coords,'unit','T').', ...
           mphinterp(model,[prefix '.Bz'],'coord',coords,'unit','T').'];
        assert(all(isfinite(B(:))),'Force-probe sample left the solved air domain.');
        normal=zeros(1,3);normal(dim)=side;
        traction=(B.*(B*normal.')-0.5*sum(B.^2,2).*normal)/mu0;
        force_N=force_N+sum(traction.*weights,1);
        torque_Nm=torque_Nm+sum(cross(points-center_m,traction,2).*weights,1);
        maxB_T=max(maxB_T,max(sqrt(sum(B.^2,2))));pointCount=pointCount+size(points,1);
    end
end
diagnostics=struct('halfSize_m',halfSize_m,'quadratureOrder',quadratureOrder, ...
    'samplePointCount',pointCount,'maxProbeB_T',maxB_T, ...
    'lateralForceRatio',norm(force_N(2:3))/max(abs(force_N(1)),eps), ...
    'torqueNorm_Nm',norm(torque_Nm));
end

function [nodes,weights]=gauss_legendre_force_probe(order)
i=(1:order-1).';beta=i./sqrt(4*i.^2-1);J=diag(beta,1)+diag(beta,-1);
[vectors,values]=eig(J);nodes=diag(values);[nodes,index]=sort(nodes);vectors=vectors(:,index);weights=2*(vectors(1,:).^2).';
end
