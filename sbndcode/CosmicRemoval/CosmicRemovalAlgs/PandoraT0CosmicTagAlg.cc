#include "PandoraT0CosmicTagAlg.h"

namespace sbnd{

PandoraT0CosmicTagAlg::PandoraT0CosmicTagAlg(const Config& config){

  this->reconfigure(config);

}


PandoraT0CosmicTagAlg::PandoraT0CosmicTagAlg(){

}


PandoraT0CosmicTagAlg::~PandoraT0CosmicTagAlg(){

}


void PandoraT0CosmicTagAlg::reconfigure(const Config& config){

  fPandoraLabel = config.PandoraLabel();
  fTpcTrackModuleLabel = config.TpcTrackModuleLabel();
  fBeamTimeMin = config.BeamTimeLimits().BeamTimeMin();
  fBeamTimeMax = config.BeamTimeLimits().BeamTimeMax();

  return;
}

bool PandoraT0CosmicTagAlg::PandoraT0CosmicTag(recob::Track track, const art::Event& event){

  // Get the pfps and associations
  art::Handle< std::vector<recob::PFParticle> > pfParticleHandle;
  event.getByLabel(fPandoraLabel, pfParticleHandle);
  art::FindManyP<recob::Track> pfPartToTrackAssoc(pfParticleHandle, event, fTpcTrackModuleLabel);
  art::FindManyP<anab::T0> findManyT0(pfParticleHandle, event, fPandoraLabel);

  // Loop over all the pfps
  for(auto const pfp : (*pfParticleHandle)){
    // Get the associated track if there is one
    const std::vector< art::Ptr<recob::Track> > associatedTracks(pfPartToTrackAssoc.at(pfp.Self()));
    if(associatedTracks.size() != 1) continue;
    recob::Track trk = *associatedTracks.front();
    if(trk.ID() != track.ID()) continue;
    // Get the associated t0
    const std::vector< art::Ptr<anab::T0> > associatedT0s(findManyT0.at(pfp.Self()));

    // If any t0 outside of beam limits then remove
    for(size_t i = 0; i < associatedT0s.size(); i++){
      double pandoraTime = associatedT0s[i]->Time()*1e-3; // [us]
      if(pandoraTime < fBeamTimeMin || pandoraTime > fBeamTimeMax) return true;
    }
  }

  return false;

}

bool PandoraT0CosmicTagAlg::PandoraT0CosmicTag(recob::PFParticle pfparticle, std::map< size_t, art::Ptr<recob::PFParticle> > pfParticleMap, const art::Event& event){

  // Get pfp associations to t0s
  art::Handle< std::vector<recob::PFParticle> > pfParticleHandle;
  event.getByLabel(fPandoraLabel, pfParticleHandle);
  art::FindManyP<anab::T0> findManyT0(pfParticleHandle, event, fPandoraLabel);

  // Loop over daughters
  for (const size_t daughterId : pfparticle.Daughters()){
    // Get associated t0s
    art::Ptr<recob::PFParticle> pParticle = pfParticleMap.at(daughterId);
    const std::vector< art::Ptr<anab::T0> > associatedT0s(findManyT0.at(pParticle.key()));

    // If any t0 outside of beam limits then remove
    for(size_t i = 0; i < associatedT0s.size(); i++){
      double pandoraTime = associatedT0s[i]->Time()*1e-3; // [us]
      if(pandoraTime < fBeamTimeMin || pandoraTime > fBeamTimeMax) return true;
    }
  }

  return false;

}


}